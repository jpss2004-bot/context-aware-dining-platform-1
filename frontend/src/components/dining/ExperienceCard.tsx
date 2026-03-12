import Badge from "../ui/Badge";
import Card from "../ui/Card";
import { Experience } from "../../types";

type ExperienceCardProps = {
  experience: Experience;
};

function formatDate(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric"
  });
}

export default function ExperienceCard({ experience }: ExperienceCardProps) {
  return (
    <Card
      className="experience-card"
      title={experience.title || "Untitled experience"}
      subtitle={`Saved ${formatDate(experience.created_at)}`}
      actions={
        experience.overall_rating !== null ? (
          <Badge tone="success">{experience.overall_rating}/5</Badge>
        ) : (
          <Badge>Unrated</Badge>
        )
      }
    >
      <div>
        {experience.occasion ? <Badge>{experience.occasion}</Badge> : null}
        {experience.social_context ? (
          <Badge tone="accent">{experience.social_context}</Badge>
        ) : null}
      </div>

      <p className="muted" style={{ margin: 0 }}>
        {experience.notes || "No notes were added for this experience."}
      </p>

      {experience.ratings.length > 0 ? (
        <div>
          {experience.ratings.map((rating) => (
            <Badge key={rating.id} tone="warning">
              {rating.category}: {rating.score}
            </Badge>
          ))}
        </div>
      ) : (
        <div>
          <Badge>No category ratings</Badge>
        </div>
      )}
    </Card>
  );
}
